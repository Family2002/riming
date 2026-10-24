import type { Metadata } from "next";
import { Noto_Sans_SC, Source_Sans_3 } from "next/font/google";
import localFont from "next/font/local";

import "./globals.css";

const sourceSans = Source_Sans_3({
  variable: "--font-ui",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const notoSansSc = Noto_Sans_SC({
  variable: "--font-cjk",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

// Same family as Flutter `GoogleFonts.maShanZheng` (AppBar 「日铭」).
const maShanZheng = localFont({
  src: "../fonts/MaShanZheng-Regular.ttf",
  variable: "--font-brand",
  weight: "400",
  display: "swap",
});

export const metadata: Metadata = {
  title: "日铭 · 分析",
  description: "日铭活动记录的网页分析与导出",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="zh-CN"
      className={`${sourceSans.variable} ${notoSansSc.variable} ${maShanZheng.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
