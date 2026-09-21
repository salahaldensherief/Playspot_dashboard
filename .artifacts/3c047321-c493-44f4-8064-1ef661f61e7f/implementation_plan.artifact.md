# Plan to Fix Supabase Profiles & Cities API Errors

Fix two recurring API errors reported in Supabase logs:
1. `400 Bad Request` (`column cities_1.name does not exist` ~41 times/day) when querying `profiles` embedded with `cities`. `cities` table only contains `name_ar` and `name_en`.
2. `400 Bad Request` (`invalid input syntax for type uuid: "undefined"` ~26 times/day) on `PATCH /profiles` when updating user profile data.

## Proposed Changes

### [Core Auth & User Domain]

#### [MODIFY] [user_entity.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/auth/domain/entities/user_entity.dart)
- Add locale-aware city display getter `getDisplayCityName({String? languageCode})`.
- Return `cityNameAr` for Arabic / default, and `cityNameEn` for English, falling back gracefully if one is empty.

#### [MODIFY] [user_model.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/auth/data/models/user_model.dart)
- Add static `isValidUuid(String? str)` and `cleanUuid(dynamic value)` helper methods to ensure `cityId` is never set to `"undefined"` or invalid string.
- Safely parse `cityNameAr` and `cityNameEn` from embedded `cities` object (`json['cities']?['name_ar']`, `json['cities']?['name_en']`).
- Add `sanitizeProfilePayload(Map<String, dynamic> data)` to cleanse profile update/PATCH payloads:
  - Remove keys with `null`, `"undefined"`, or `"null"` values.
  - Require `city_id` (and other UUID keys) to match valid 36-character UUID format before inclusion.
- Update `toJson()` to use payload sanitization.

### [Data Sources & Repositories]

#### [MODIFY] [auth_remote_data_source.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/auth/data/data_source/auth_remote_data_source.dart)
- Update `getCurrentUser()` `profiles` table select query to embed `cities` via `cities:city_id(id, name_ar, name_en)` instead of plain `.select()` or requesting non-existent `name` column.

#### [MODIFY] [admin_management_remote_data_source.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/users/data/datasources/admin_management_remote_data_source.dart)
- Update `getAdmins()` query to select `cities:city_id(id, name_ar, name_en)`.
- Update `updateAdmin()` to sanitize update payloads via `UserModel.sanitizeProfilePayload(data)` before executing `.update()` on `profiles`.

#### [MODIFY] [staff_remote_data_source.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/staff/data/data_source/remote/staff_remote_data_source.dart)
- Sanitize profile updates in `updateStaff()` to filter out invalid UUIDs and `null`/`undefined` keys.

### [UI Presentation]

#### [MODIFY] [profile_page.dart](file:///D:/flutter_projects/play_spot_dashboard/lib/features/auth/presentation/profile/profile_page.dart)
- Update user city text field to display localized city name based on active app language.

### [Automated Tests]

#### [NEW] [user_model_city_test.dart](file:///D:/flutter_projects/play_spot_dashboard/test/features/auth/data/user_model_city_test.dart)
- Unit tests for parsing profiles with cities and sanitizing profile payloads:
  1. Test Case 1 (User with selected city): Valid UUID `city_id` and embedded `cities` with `name_ar` & `name_en`.
  2. Test Case 2 (User without city / undefined): `city_id="undefined"`, `null` or missing city data.

## Verification Plan

### Automated Tests
- Run `flutter test test/features/auth/data/user_model_city_test.dart` to verify both test cases.

### Manual Verification
- Verify `UserModel` serialization strips `city_id: "undefined"` and `null` keys.
- Verify `getCurrentUser` profile fetch constructs query with `cities:city_id(id, name_ar, name_en)`.
