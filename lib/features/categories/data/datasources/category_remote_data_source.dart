import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);

  // Cities
  Future<List<CityModel>> getCities();
  Future<void> addCity(CityModel city);
  Future<void> updateCity(CityModel city);
  Future<void> deleteCity(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient _supabase;

  CategoryRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase.from('categories').select().order('name_en');
    return (response as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await _supabase.from('categories').insert(category.toJson());
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _supabase.from('categories').update(category.toJson()).eq('id', category.id);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }

  // Cities implementation
  @override
  Future<List<CityModel>> getCities() async {
    final response = await _supabase.from('cities').select().order('name_en');
    return (response as List).map((json) => CityModel.fromJson(json)).toList();
  }

  @override
  Future<void> addCity(CityModel city) async {
    await _supabase.from('cities').insert(city.toJson());
  }

  @override
  Future<void> updateCity(CityModel city) async {
    await _supabase.from('cities').update(city.toJson()).eq('id', city.id);
  }

  @override
  Future<void> deleteCity(String id) async {
    await _supabase.from('cities').delete().eq('id', id);
  }
}
