import { Controller, Get, Delete, Param, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req: any) {
    const userId = req.user.sub;
    const { data, error } = await this.usersService.getUserById(userId);

    if (error || !data) {
      return { error: 'Usuário não encontrado' };
    }

    const user = data.user;
    if (!user) {
      return { error: 'Usuário não encontrado' };
    }

    const metadata = user.user_metadata || {};
    return {
      id: user.id,
      email: user.email,
      name: metadata.name,
      picture: metadata.picture,
      provider: metadata.provider,
      // emailVerified: user.email_confirmed_at !== null,
    };
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  async deleteAccount(@Req() req: any) {
    const userId = req.user.sub;
    const result = await this.usersService.deleteUser(userId);
    return { message: 'Conta deletada com sucesso' };
  }
}
