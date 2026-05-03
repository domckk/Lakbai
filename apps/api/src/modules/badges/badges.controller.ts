import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { BadgesService } from './badges.service';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';

@ApiTags('badges')
@ApiBearerAuth()
@Controller()
export class BadgesController {
  constructor(private readonly badges: BadgesService) {}

  @Get('badges')
  findAll() {
    return this.badges.findAll();
  }

  @Get('me/badges')
  forUser(@CurrentUser() user: AuthUser) {
    return this.badges.forUser(user.sub);
  }
}
