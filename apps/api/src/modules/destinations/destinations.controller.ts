import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { DestinationsService } from './destinations.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('destinations')
@Controller('destinations')
export class DestinationsController {
  constructor(private readonly destinations: DestinationsService) {}

  @Public()
  @Get()
  list() {
    return this.destinations.list();
  }

  @Public()
  @Get(':slug')
  bySlug(@Param('slug') slug: string) {
    return this.destinations.findBySlug(slug);
  }
}
