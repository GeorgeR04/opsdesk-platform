import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    files: ["**/*.{js,ts,tsx}"],
    rules: {
      "no-unused-vars": "warn"
    }
  }
];
