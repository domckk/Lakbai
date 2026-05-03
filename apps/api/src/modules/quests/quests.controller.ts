import { Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max } from 'class-validator';
import { QuestsService } from './quests.service';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';

class QuestQueryDto {
  @IsOptional() @IsString() destinationSlug?: string;
  @IsOptional() @IsString() type?: string;
  @IsOptional() @IsInt() @Min(1) @Max(5) difficulty?: number;
}

@ApiTags('quests')
@Controller('quests')
export class QuestsController {
  constructor(private readonly quests: QuestsService) {}

  @Public()
  @Get()
  list(@Query() q: QuestQueryDto) {
    return this.quests.list(q);
  }

  @Public()
  @Get(':id')
  byId(@Param('id') id: string) {
    return this.quests.findById(id);
  }

  @ApiBearerAuth()
  @Post(':id/start')
  start(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.quests.start(user.sub, id);
  }
}
