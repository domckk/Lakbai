import { Module } from '@nestjs/common';
import { CheckpointsController } from './checkpoints.controller';
import { CheckpointsService } from './checkpoints.service';
import { QrService } from './qr.service';
import { AntiCheatService } from './anti-cheat.service';
import { ProgressionModule } from '../progression/progression.module';

@Module({
  imports: [ProgressionModule],
  controllers: [CheckpointsController],
  providers: [CheckpointsService, QrService, AntiCheatService],
  exports: [CheckpointsService, QrService],
})
export class CheckpointsModule {}
