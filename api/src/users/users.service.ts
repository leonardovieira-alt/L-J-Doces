import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class UsersService {
  constructor(private supabaseService: SupabaseService) {}

  async getUserById(userId: string) {
    return this.supabaseService.getUserById(userId);
  }

  async getUserByEmail(email: string) {
    const supabase = this.supabaseService.getClient();
    return await supabase.auth.admin.listUsers();
  }

  async updateUserProfile(userId: string, updateData: any) {
    return this.supabaseService.updateUserMetadata(userId, updateData);
  }

  async deleteUser(userId: string) {
    return this.supabaseService.deleteUser(userId);
  }
}
