import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/cashier_session_details.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';

typedef CashierWorkspaceMount =
    Future<void> Function(
      WidgetTester tester,
      double width,
      String locale,
      double scale, {
      List<Booking>? bookings,
      ValueChanged<Booking>? onManage,
      ValueNotifier<bool>? workspaceVisibility,
      List<ClientRequestEntity>? clientRequests,
    });

class CashierWorkspaceInteractionTests {
  static void register(
    CashierWorkspaceMount mount,
    Booking primary,
    ClientRequestEntity request,
  ) {
    _management(mount, primary);
    _ownerDisposal(mount, primary);
    _venueRequests(mount, primary, request);
    _venueTransition(mount, primary);
  }

  static void _venueTransition(CashierWorkspaceMount mount, Booking primary) {
    testWidgets('open sheet cannot show a replacement from another venue', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, 360, 'ar', 1, bookings: [primary]);
      await tester.tap(find.text(primary.roomName).first);
      await tester.pumpAndSettle();
      expect(find.byType(CashierSessionDetails), findsOneWidget);
      await mount(
        tester,
        360,
        'ar',
        1,
        bookings: [
          primary.copyWith(loungeId: 'other', roomName: 'غرفة الصالة الأخرى'),
        ],
      );
      expect(find.byType(CashierSessionDetails), findsNothing);
      expect(find.text('إدارة الجلسة'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  static void _venueRequests(
    CashierWorkspaceMount mount,
    Booking primary,
    ClientRequestEntity request,
  ) {
    final foreign = ClientRequestEntity(
      id: 'foreign',
      loungeId: 'other',
      bookingId: primary.id,
      titleAr: 'طلب صالة أخرى',
      titleEn: 'Other venue request',
      bodyAr: 'تفاصيل خاصة بصالة أخرى',
      bodyEn: 'Other venue details',
      type: ClientRequestType.callStaff,
      createdAt: request.createdAt,
    );
    for (final width in [360.0, 1440.0]) {
      testWidgets('session details exclude another venue requests at $width', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, width, 'ar', 1, clientRequests: [request, foreign]);
        if (width <= 600) {
          await tester.tap(find.text(primary.roomName).first);
          await tester.pumpAndSettle();
        }
        expect(find.text(request.titleAr), findsOneWidget);
        expect(find.text(foreign.titleAr), findsNothing);
        expect(find.text(foreign.bodyAr), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  static void _management(CashierWorkspaceMount mount, Booking primary) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets(
        'session management is reachable without scrolling at $width with large Arabic text',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final managed = <String>[];
          await mount(
            tester,
            width,
            'ar',
            1.6,
            onManage: (booking) => managed.add(booking.id),
          );
          if (width <= 600) {
            await tester.tap(find.text(primary.roomName).first);
            await tester.pumpAndSettle();
          }
          final action = find.text('إدارة الجلسة');
          expect(action, findsOneWidget);
          final bounds = tester.getRect(action);
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(
            bounds.bottom,
            lessThanOrEqualTo(tester.view.physicalSize.height),
          );
          await tester.tap(action);
          await tester.pump();
          expect(managed, [primary.id]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  static void _ownerDisposal(CashierWorkspaceMount mount, Booking primary) {
    for (final width in [360.0, 600.0]) {
      testWidgets(
        'removing workspace closes only its owned details sheet at $width',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final visible = ValueNotifier(true);
          addTearDown(visible.dispose);
          await mount(tester, width, 'ar', 1.6, workspaceVisibility: visible);
          await tester.tap(find.text(primary.roomName).first);
          await tester.pumpAndSettle();
          expect(find.byType(CashierSessionDetails), findsOneWidget);
          visible.value = false;
          await tester.pumpAndSettle();
          expect(find.byType(CashierSessionDetails), findsNothing);
          expect(find.text('إدارة الجلسة'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
