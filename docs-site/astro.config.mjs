import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

export default defineConfig({
  srcDir: "./src",
  site: "https://127.0.0.1:4321",
  integrations: [
    starlight({
      title: "D2 Build Creator docs",
      description:
        "PRDs, domain law, and ops — read, review, propose change requests.",
      editLink: {
        baseUrl:
          "https://github.com/DCForever/AI-Destiny-2-Build-Creator/blob/main/",
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/DCForever/AI-Destiny-2-Build-Creator",
        },
      ],
      sidebar: [
        { label: "Home", slug: "" },
        { label: "Layers", slug: "layers" },
        { label: "Change requests", slug: "change-requests" },
        {
          label: "Product",
          items: [{ autogenerate: { directory: "product" } }],
        },
        {
          label: "PRDs (from Obsidian)",
          items: [{ autogenerate: { directory: "prd" } }],
        },
        {
          label: "Law",
          items: [{ autogenerate: { directory: "law" } }],
        },
        {
          label: "Ops",
          items: [{ autogenerate: { directory: "ops" } }],
        },
      ],
      components: {
        Footer: "./src/components/FooterWithPropose.astro",
      },
      customCss: ["./src/styles/propose.css"],
    }),
  ],
});
