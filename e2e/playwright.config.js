const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 60000,
  retries: 1,
  use: {
    headless: true,
  },
  projects: [
    {
      name: 'counter',
      use: {
        baseURL: process.env.COUNTER_URL || 'http://localhost:5001',
      },
      testMatch: '**/01-counter.spec.js',
    },
    {
      name: 'todo',
      use: {
        baseURL: process.env.TODO_URL || 'http://localhost:5002',
      },
      testMatch: '**/02-todo.spec.js',
    },
    {
      name: 'books',
      use: {
        baseURL: process.env.BOOKS_URL || 'http://localhost:5003',
      },
      testMatch: '**/03-books.spec.js',
    },
    {
      name: 'login',
      use: {
        baseURL: process.env.LOGIN_URL || 'http://localhost:5004',
      },
      testMatch: '**/04-login.spec.js',
    },
    {
      name: 'error-handling',
      use: {
        baseURL: process.env.ERROR_HANDLING_URL || 'http://localhost:5006',
      },
      testMatch: '**/06-error-handling.spec.js',
    },
    {
      name: 'data-table',
      use: {
        baseURL: process.env.DATA_TABLE_URL || 'http://localhost:5008',
      },
      testMatch: '**/08-data-table.spec.js',
    },
    {
      name: 'dialog',
      use: {
        baseURL: process.env.DIALOG_URL || 'http://localhost:5009',
      },
      testMatch: '**/09-dialog.spec.js',
    },
  ],
});
