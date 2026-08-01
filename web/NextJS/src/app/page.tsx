import { redirect } from "next/navigation";

/** Generator retired from primary nav — curated Build is home. */
export default function Home() {
  redirect("/build");
}
