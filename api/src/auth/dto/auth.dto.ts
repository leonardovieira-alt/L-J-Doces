import { IsEmail, IsString, MinLength, IsNotEmpty, Matches } from 'class-validator';

export class SignUpDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: 'Senha deve conter pelo menos uma letra maiúscula, uma minúscula e um número',
  })
  password: string;

  @IsString()
  @IsNotEmpty()
  confirmPassword: string;
}

export class SignInDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty()
  code: string;
}

export class ResendConfirmationDto {
  @IsEmail()
  email: string;
}
