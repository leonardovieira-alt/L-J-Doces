import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { BannersService } from './banners.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('banners')
export class BannersController {
  constructor(private readonly bannersService: BannersService) {}

  @Get()
  async getBanners() {
    return this.bannersService.getBanners();
  }

  @UseGuards(JwtAuthGuard, AdminGuard)
  @Post()
  async createBanner(@Body() data: any) {
    return this.bannersService.createBanner(data);
  }

  @UseGuards(JwtAuthGuard, AdminGuard)
  @Put(':id')
  async updateBanner(@Param('id') id: string, @Body() data: any) {
    return this.bannersService.updateBanner(id, data);
  }

  @UseGuards(JwtAuthGuard, AdminGuard)
  @Delete(':id')
  async deleteBanner(@Param('id') id: string) {
    return this.bannersService.deleteBanner(id);
  }
}
