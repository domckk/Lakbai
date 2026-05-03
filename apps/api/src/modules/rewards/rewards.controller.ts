import { Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RewardsService } from './rewards.service';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';

@ApiTags('rewards')
@ApiBearerAuth()
@Controller()
export class RewardsController {
  constructor(private readonly rewards: RewardsService) {}

  @Get('rewards')
  available(@CurrentUser() user: AuthUser) {
    return this.rewards.availableForUser(user.sub);
  }

  @Get('me/rewards')
  wallet(@CurrentUser() user: AuthUser) {
    return this.rewards.wallet(user.sub);
  }

  @Post('me/rewards/:id/redeem')
  redeem(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.rewards.redeem(user.sub, id);
  }
}
