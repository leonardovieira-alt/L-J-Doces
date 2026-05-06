import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ProductsService {
  constructor(private supabase: SupabaseService) {}

  async getProducts() {
    const client = this.supabase.getClient();
    const { data, error } = await client.from('products').select(`*, category:categories(name), subcategory:subcategories(name)`);
    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async createProduct(data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('products')
      .insert([data])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async updateProduct(id: string, data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('products')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async deleteProduct(id: string) {
    const client = this.supabase.getClient();
    const { error } = await client.from('products').delete().eq('id', id);
    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }
}
