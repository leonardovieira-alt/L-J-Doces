import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class BannersService {
  constructor(private supabase: SupabaseService) {}

  async getBanners() {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('banners')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      if (error.code === '42P01') {
        // Tabela ainda não existe
        return [];
      }
      throw new BadRequestException(error.message);
    }
    return data;
  }

  async createBanner(data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('banners')
      .insert([data])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async updateBanner(id: string, data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('banners')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async deleteBanner(id: string) {
    const client = this.supabase.getClient();
    const { error } = await client.from('banners').delete().eq('id', id);
    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }
}
