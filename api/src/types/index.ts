export interface User {
  id: string;
  email: string;
  name: string;
  picture?: string;
  provider?: 'email' | 'google';
  emailVerified?: boolean;
  admin?: boolean;
}

export interface AuthResponse {
  success: boolean;
  token?: string;
  user?: User;
  message?: string;
  error?: string;
}

export interface JwtPayload {
  sub: string;
  email: string;
  name: string;
  provider?: string;
}

export interface SignUpRequest {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface SignInRequest {
  email: string;
  password: string;
}

export interface UpdateProfileRequest {
  name?: string;
  picture?: string;
}
