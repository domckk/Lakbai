import { Module } from '@nestjs/common';
import { ProgressionService } from './progression.service';
import { BadgesModule } from '../badges/badges.module';

@Module({
  imports: [BadgesModule],
  providers: [ProgressionService],
  exports: [ProgressionService],
})
export class ProgressionModule {}
