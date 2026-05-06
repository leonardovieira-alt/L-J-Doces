import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class OrdersService {
  constructor(private supabaseService: SupabaseService) {}

  async createOrder(userId: string, createOrderDto: CreateOrderDto) {
    const supabase = this.supabaseService.getClient();
    const orderId = uuidv4();
    const now = new Date().toISOString();

    try {
      // Criar pedido
      const { data: orderData, error: orderError } = await supabase
        .from('orders')
        .insert({
          id: orderId,
          user_id: userId,
          status: 'pending',
          total_amount: createOrderDto.total_amount,
          created_at: now,
          updated_at: now,
        })
        .select();

      if (orderError) throw orderError;

      // Criar itens do pedido
      const orderItems = createOrderDto.items.map((item) => ({
        id: uuidv4(),
        order_id: orderId,
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        observation: item.observation || null,
        created_at: now,
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) throw itemsError;

      // Criar registro de pagamento
      const { error: paymentError } = await supabase
        .from('payments')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          amount: createOrderDto.total_amount,
          status: 'pending',
          payment_method: 'simulated',
          created_at: now,
          updated_at: now,
        });

      if (paymentError) throw paymentError;

      // Criar rastreamento inicial
      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: 'pending',
          message: 'Pedido criado com sucesso',
          created_at: now,
        });

      if (trackingError) throw trackingError;

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }

  async simulatePayment(orderId: string, userId: string) {
    const supabase = this.supabaseService.getClient();
    const now = new Date().toISOString();

    try {
      // Verificar se o pedido pertence ao usuário
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('*')
        .eq('id', orderId)
        .eq('user_id', userId)
        .single();

      if (orderError || !order) {
        throw new Error('Pedido não encontrado');
      }

      // Atualizar status do pagamento
      const transactionId = `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const receiptNumber = `RCP-${uuidv4().slice(0, 8).toUpperCase()}`;

      const { error: paymentError } = await supabase
        .from('payments')
        .update({
          status: 'completed',
          transaction_id: transactionId,
          receipt_number: receiptNumber,
          paid_at: now,
          updated_at: now,
        })
        .eq('order_id', orderId);

      if (paymentError) throw paymentError;

      // Atualizar status do pedido
      const { error: updateError } = await supabase
        .from('orders')
        .update({
          status: 'confirmed',
          updated_at: now,
        })
        .eq('id', orderId);

      if (updateError) throw updateError;

      // Adicionar rastreamento
      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: 'confirmed',
          message: `Pagamento confirmado. Comprovante: ${receiptNumber}`,
          created_at: now,
        });

      if (trackingError) throw trackingError;

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }

  async getUserOrders(userId: string) {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*),
          payments(*),
          order_tracking(*)
        `
        )
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      // Attach basic user info to each order (name/email) using admin API
      try {
        const augmented = await Promise.all((data as any[]).map(async (order) => {
          try {
            const userRes = await supabase.auth.admin.getUserById(order.user_id);
            const user = (userRes as any)?.data?.user || null;
            order.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
          } catch (e) {
            order.user = null;
          }
          return order;
        }));
        return augmented;
      } catch (e) {
        return data;
      }
    } catch (error) {
      throw error;
    }
  }

  async getAllOrders() {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*),
          payments(*),
          order_tracking(*)
        `
        )
        .order('created_at', { ascending: false });

      if (error) throw error;
      // Attach basic user info to each order (name/email)
      try {
        const augmented = await Promise.all((data as any[]).map(async (order) => {
          try {
            const userRes = await supabase.auth.admin.getUserById(order.user_id);
            const user = (userRes as any)?.data?.user || null;
            order.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
          } catch (e) {
            order.user = null;
          }
          return order;
        }));
        return augmented;
      } catch (e) {
        return data;
      }
    } catch (error) {
      throw error;
    }
  }

  async getOrderById(orderId: string) {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*),
          payments(*),
          order_tracking(*)
        `
        )
        .eq('id', orderId)
        .single();

      if (error) throw error;
      try {
        const userRes = await supabase.auth.admin.getUserById(data.user_id);
        const user = (userRes as any)?.data?.user || null;
        data.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
      } catch (e) {
        data.user = null;
      }
      return data;
    } catch (error) {
      throw error;
    }
  }

  async updateOrderStatus(orderId: string, status: string, message: string) {
    const supabase = this.supabaseService.getClient();
    const now = new Date().toISOString();

    try {
      const { error: updateError } = await supabase
        .from('orders')
        .update({
          status: status,
          updated_at: now,
        })
        .eq('id', orderId);

      if (updateError) throw updateError;

      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: status,
          message: message,
          created_at: now,
        });

      if (trackingError) throw trackingError;

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }
}
