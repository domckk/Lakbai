import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { LeaderboardsService } from './leaderboards.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('leaderboards')
@Controller('leaderboards')
export class LeaderboardsController {
  constructor(private readonly leaderboards: LeaderboardsService) {}

  @Public()
  @Get(':scope')
  top(@Param('scope') scope: string, @Query('limit') limit?: string) {
    const n = Math.max(1, Math.min(100, Number(limit) || 50));
    return this.leaderboards.top(scope, n);
  }
}
