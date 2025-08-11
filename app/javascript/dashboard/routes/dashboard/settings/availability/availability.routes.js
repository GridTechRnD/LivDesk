import { frontendURL } from 'dashboard/helper/URLHelper.js';

const AvailabilityPage = () => import('./Index.vue');

const meta = {
  permissions: ['administrator', 'agent', 'custom_role'],
};

const availabilityRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/availability'),
      name: 'availability',
      meta,
      component: AvailabilityPage,
    },
  ],
};

export default availabilityRoutes;
