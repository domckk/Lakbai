import { IsLatitude, IsLongitude, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CheckInDto {
  @IsLatitude()
  lat!: number;

  @IsLongitude()
  lng!: number;

  @IsNumber()
  @Min(0)
  @Max(500)
  accuracy_m!: number;

  @IsOptional()
  @IsString()
  qr_token?: string;

  @IsOptional()
  @IsString()
  device_id?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  client_ts?: number;
}
