import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Get()
  async getCategories() {
    return this.categoriesService.getCategories();
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async createCategory(@Body() body: any) {
    return this.categoriesService.createCategory(body);
  }

  @UseGuards(JwtAuthGuard)
  @Put('order')
  async updateCategoriesOrder(@Body() body: { orders: { id: string; order_index: number }[] }) {
    return this.categoriesService.updateCategoriesOrder(body.orders);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  async updateCategory(@Param('id') id: string, @Body() body: any) {
    return this.categoriesService.updateCategory(id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async deleteCategory(@Param('id') id: string) {
    return this.categoriesService.deleteCategory(id);
  }

  @UseGuards(JwtAuthGuard)
  @Put('subcategories/order')
  async updateSubcategoriesOrder(@Body() body: { orders: { id: string; order_index: number }[] }) {
    return this.categoriesService.updateSubcategoriesOrder(body.orders);
  }

  @UseGuards(JwtAuthGuard)
  @Post('subcategories')
  async createSubcategory(@Body() body: any) {
    return this.categoriesService.createSubcategory(body);
  }

  @UseGuards(JwtAuthGuard)
  @Put('subcategories/:id')
  async updateSubcategory(@Param('id') id: string, @Body() body: any) {
    return this.categoriesService.updateSubcategory(id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('subcategories/:id')
  async deleteSubcategory(@Param('id') id: string) {
    return this.categoriesService.deleteSubcategory(id);
  }
}
