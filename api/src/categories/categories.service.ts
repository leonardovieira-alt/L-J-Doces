import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class CategoriesService {
  constructor(private supabase: SupabaseService) {}

  async getCategories() {
    const client = this.supabase.getClient();
    
    const { data: categories, error: catError } = await client
      .from('categories')
      .select('*')
      .order('order_index', { ascending: true, nullsFirst: false });

    if (catError) throw new BadRequestException(catError.message);

    const { data: subcategories, error: subError } = await client
      .from('subcategories')
      .select('*')
      .order('order_index', { ascending: true, nullsFirst: false });

    if (subError) throw new BadRequestException(subError.message);

    // Format nested array
    const mapped = categories.map((cat) => ({
      ...cat,
      subcategories: subcategories.filter((sub) => sub.category_id === cat.id),
    }));

    return mapped;
  }

  async updateCategoriesOrder(orders: { id: string; order_index: number }[]) {
    const client = this.supabase.getClient();
    // Atualiza a ordem individualmente para cada id
    for (const order of orders) {
      await client
        .from('categories')
        .update({ order_index: order.order_index })
        .eq('id', order.id);
    }
    return { success: true };
  }

  async createCategory(data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('categories')
      .insert([data])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async updateCategory(id: string, data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('categories')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async deleteCategory(id: string) {
    const client = this.supabase.getClient();
    const { error } = await client.from('categories').delete().eq('id', id);
    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }

  // SUBCATEGORIAS
  async updateSubcategoriesOrder(orders: { id: string; order_index: number }[]) {
    const client = this.supabase.getClient();
    for (const order of orders) {
      await client
        .from('subcategories')
        .update({ order_index: order.order_index })
        .eq('id', order.id);
    }
    return { success: true };
  }

  async createSubcategory(data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('subcategories')
      .insert([data])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async updateSubcategory(id: string, data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('subcategories')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async deleteSubcategory(id: string) {
    const client = this.supabase.getClient();
    const { error } = await client.from('subcategories').delete().eq('id', id);
    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }
}
