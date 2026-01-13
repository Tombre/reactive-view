import { type ParentProps } from "solid-js";
import Navigation from "./Navigation";
import "~/styles/tailwind.css";

interface MainLayoutProps extends ParentProps {
  title?: string;
  showNav?: boolean;
}

export default function MainLayout(props: MainLayoutProps) {
  return (
    <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <div class="max-w-6xl mx-auto px-6 sm:px-8 lg:px-12 py-8 space-y-10">
        {props.showNav !== false && <Navigation />}
        
        {props.title && (
          <h1 class="text-4xl font-bold text-gray-900 tracking-tight">{props.title}</h1>
        )}
        
        <div class="space-y-8">
          {props.children}
        </div>
      </div>
    </div>
  );
}
