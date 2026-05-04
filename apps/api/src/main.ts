import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { join } from 'path';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { bufferLogs: true });
  const config = app.get(ConfigService);
  const isProd = config.get<string>('NODE_ENV') === 'production';

  // Security headers — must be first middleware.
  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow CDN-served images
  }));

  // Serve uploaded avatars (UUIDs as filenames, low-guessability).
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' });

  app.setGlobalPrefix('v1', { exclude: ['health', 'docs'] });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());

  // CORS — deny all origins if CORS_ORIGINS is not configured in production.
  const corsOrigins = (config.get<string>('CORS_ORIGINS') ?? '').split(',').filter(Boolean);
  app.enableCors({
    origin: corsOrigins.length ? corsOrigins : (isProd ? false : true),
    credentials: true,
  });

  // Swagger — development only; never expose API schema in production.
  if (!isProd) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Trail Quest API')
      .setDescription('Gamified digital tourism platform — REST API')
      .setVersion('0.1.0')
      .addBearerAuth()
      .build();
    const doc = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('docs', app, doc);
  }

  const port = config.get<number>('API_PORT') ?? 4000;
  await app.listen(port);
  Logger.log(
    `Trail Quest API listening on http://localhost:${port}${isProd ? '' : '  (docs at /docs)'}`,
    'Bootstrap',
  );
}

bootstrap();
