import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // Verifica se o usuário está autenticado e tem a propriedade admin
    if (user && (user.admin === true || user.admin === 'true')) {
      return true;
    }

    throw new ForbiddenException('Acesso restrito a administradores.');
  }
}
