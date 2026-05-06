import { Injectable, BadRequestException } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  constructor() {
    // Apenas certifica que a variável de ambiente URL padrão está sendo lida.
    // O SDK v2 já puxa o `CLOUDINARY_URL` da string .env se configurardo no app.
    if (process.env.CLOUDINARY_URL) {
      cloudinary.config(true);
    } else {
      cloudinary.config({
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dtipuhvmj',
        api_key: process.env.CLOUDINARY_API_KEY || '826857144614938',
        api_secret: process.env.CLOUDINARY_API_SECRET || '6BttZ4knw8PvyQBmeTcXJW7CTcE',
      });
    }
  }

  async uploadBuffer(buffer: Buffer, originalName: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder: 'app_uploads' },
        (error, result) => {
          if (error) {
            console.error('Erro no Cloudinary:', error);
            return reject(new BadRequestException('Erro ao enviar imagem para Cloudinary: ' + (error.message || JSON.stringify(error))));
          }
          resolve(result.secure_url);
        },
      );
      streamifier.createReadStream(buffer).pipe(uploadStream);
    });
  }
}
