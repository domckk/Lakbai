import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CheckpointsService } from './checkpoints.service';
import { CheckInDto } from './dto';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('checkpoints')
@ApiBearerAuth()
@Controller('checkpoints')
export class CheckpointsController {
  constructor(private readonly checkpoints: CheckpointsService) {}

  @Post(':id/checkin')
  checkIn(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: CheckInDto) {
    return this.checkpoints.checkIn(user.sub, id, dto);
  }

  /** Partner / staff endpoint — generate a rotating QR token for posters or POS displays. */
  @Roles('partner', 'lgu_admin', 'staff')
  @Get(':id/qr-token')
  issue(@Param('id') id: string) {
    return this.checkpoints.issueQrToken(id);
  }
}
