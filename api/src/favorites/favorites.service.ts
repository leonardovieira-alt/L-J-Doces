import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class FavoritesService {
  constructor(private supabase: SupabaseService) {}

  async getFavorites(userId: string) {
    const client = this.supabase.getClient();
    // Assuming table name is "favorites"
    const { data, error } = await client
      .from('favorites')
      .select('product_id, products(*)')
      .eq('user_id', userId);

    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async addFavorite(userId: string, productId: string) {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('favorites')
      .insert([{ user_id: userId, product_id: productId }])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async removeFavorite(userId: string, productId: string) {
    const client = this.supabase.getClient();
    const { error } = await client
      .from('favorites')
      .delete()
      .match({ user_id: userId, product_id: productId });

    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }
}
