import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  Headers,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { AuthService } from '../auth/auth.service';

@Controller('orders')
export class OrdersController {
  constructor(
    private ordersService: OrdersService,
    private authService: AuthService,
  ) {}

  private getToken(authHeader?: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
    }

    return authHeader.replace('Bearer ', '');
  }

  @Post()
  async createOrder(
    @Headers('Authorization') authHeader: string,
    @Body() createOrderDto: CreateOrderDto,
  ) {
    try {
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      const order = await this.ordersService.createOrder(
        userId,
        createOrderDto,
      );
      return order;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao criar pedido',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get()
  async getUserOrders(@Headers('Authorization') authHeader: string) {
    try {
      console.log('[ORDERS] GET /orders - Authorization header:', authHeader);
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      console.log('[ORDERS] Resolved userId:', userId);
      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      const orders = await this.ordersService.getUserOrders(userId);
      return orders;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao buscar pedidos',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('admin')
  async getAllOrders(@Headers('Authorization') authHeader: string) {
    try {
      console.log('[ORDERS] GET /orders/admin - Authorization header:', authHeader);
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      console.log('[ORDERS] Resolved userId (admin request):', userId);
      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      const user = await this.authService.getProfile(userId);
      if (!user || !user.admin) {
        throw new HttpException('Forbidden', HttpStatus.FORBIDDEN);
      }

      const orders = await this.ordersService.getAllOrders();
      return orders;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao buscar pedidos',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get(':id')
  async getOrderById(
    @Param('id') orderId: string,
    @Headers('Authorization') authHeader: string,
  ) {
    try {
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      const order = await this.ordersService.getOrderById(orderId);

      // Verificar se o pedido pertence ao usuário
      if (order.user_id !== userId) {
        throw new HttpException('Forbidden', HttpStatus.FORBIDDEN);
      }

      return order;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao buscar pedido',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post(':id/pay')
  async simulatePayment(
    @Param('id') orderId: string,
    @Headers('Authorization') authHeader: string,
  ) {
    try {
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      const order = await this.ordersService.simulatePayment(orderId, userId);
      return order;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao processar pagamento',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post(':id/status')
  async updateOrderStatus(
    @Param('id') orderId: string,
    @Body('status') status: string,
    @Body('message') message: string,
    @Headers('Authorization') authHeader: string,
  ) {
    try {
      const token = this.getToken(authHeader);
      const userId = await this.authService.getUserIdFromToken(token);

      if (!userId) {
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      }

      // Verificar se é admin
      const user = await this.authService.getProfile(userId);
      if (!user.admin) {
        throw new HttpException('Forbidden', HttpStatus.FORBIDDEN);
      }

      const order = await this.ordersService.updateOrderStatus(
        orderId,
        status,
        message,
      );
      return order;
    } catch (error: any) {
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        error.message || 'Erro ao atualizar pedido',
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}
