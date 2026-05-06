# Auth API - NestJS + Supabase

API de autenticação com suporte a Email/Senha e Google OAuth.

## Instalação

```bash
npm install
```

## Configuração

1. Configure as variáveis de ambiente no arquivo `.env`:

```env
SUPABASE_URL=seu-url-do-supabase
SUPABASE_ANON_KEY=sua-chave-anonima
SUPABASE_SERVICE_ROLE_KEY=sua-chave-de-servico

JWT_SECRET=sua-chave-secreta-jwt
JWT_EXPIRATION=7d

GOOGLE_CLIENT_ID=seu-google-client-id
GOOGLE_CLIENT_SECRET=seu-google-client-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback
```

2. Instale as dependências:

```bash
npm install
```

## Executar

```bash
# Desenvolvimento
npm run start:dev

# Produção
npm run start:prod
```

A API estará disponível em `http://localhost:3000`

## Rotas Disponíveis

### Autenticação

- `POST /auth/signup` - Registrar novo usuário
- `POST /auth/signin` - Fazer login
- `GET /auth/google` - Autenticar com Google
- `GET /auth/profile` - Obter perfil (requer token)
- `POST /auth/profile/update` - Atualizar perfil (requer token)

### Usuários

- `GET /users/me` - Obter informações do usuário logado
- `DELETE /users/me` - Deletar conta

## Estrutura do Projeto

```
src/
├── auth/
│   ├── dto/
│   ├── guards/
│   ├── strategies/
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   └── auth.module.ts
├── users/
│   ├── users.controller.ts
│   ├── users.service.ts
│   └── users.module.ts
├── supabase/
│   ├── supabase.service.ts
│   └── supabase.module.ts
├── app.module.ts
└── main.ts
```
