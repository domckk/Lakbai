/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        trail: {
          cream: '#FFFDF5',
          peach: '#FFD4A8',
          orange: '#FF8C3B',
          'orange-dark': '#E07028',
          brown: '#3D2000',
          'brown-mid': '#5C2D0A',
        },
      },
    },
  },
  plugins: [],
};
