// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'TaskLang++ Docs',
  tagline: 'Documentation for the TaskLang++ DSL',
  url: 'https://your-docusaurus-site.com',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: '/', // This serves your docs at the root of the site
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'), // Ensure this file exists, or remove this line
        },
      }),
    ],
  ],
};

module.exports = config;