import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
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
}
