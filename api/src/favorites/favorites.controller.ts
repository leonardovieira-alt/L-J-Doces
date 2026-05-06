import { Controller, Get, Post, Delete, Param, UseGuards, Request } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  async getFavorites(@Request() req) {
    const userId = req.user?.id || req.user?.sub;
    return this.favoritesService.getFavorites(userId);
  }

  @Post(':productId')
  async addFavorite(@Request() req, @Param('productId') productId: string) {
    const userId = req.user?.id || req.user?.sub;
    return this.favoritesService.addFavorite(userId, productId);
  }

  @Delete(':productId')
  async removeFavorite(@Request() req, @Param('productId') productId: string) {
    const userId = req.user?.id || req.user?.sub;
    return this.favoritesService.removeFavorite(userId, productId);
  }
}
