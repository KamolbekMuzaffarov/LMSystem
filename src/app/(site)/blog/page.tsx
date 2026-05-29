import type { Metadata } from "next";
import { Clock, ArrowUpRight } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { PageHeader } from "@/components/layout/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";
import { TiltCard } from "@/components/ui/TiltCard";
import { Stagger, StaggerItem } from "@/components/ui/Reveal";
import { blogPosts } from "@/lib/mock/blog";
import { cn, formatDateUz } from "@/lib/utils";

export const metadata: Metadata = { title: "Blog" };

export default function BlogPage() {
  return (
    <>
      <PageHeader
        eyebrow="Blog va yangiliklar"
        title={<>Foydali <span className="gradient-text">maqolalar</span></>}
        subtitle="O'qituvchilarimizdan amaliy maslahatlar, strategiyalar va yangiliklar."
      />

      <Container className="pb-10">
        <Stagger className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {blogPosts.map((post) => (
            <StaggerItem key={post.slug} className="h-full">
              <TiltCard className="h-full" intensity={6}>
                <GlassCard sheen className="group flex h-full flex-col overflow-hidden p-0">
                  <div className={cn("relative flex h-36 items-center justify-center bg-gradient-to-br", post.gradient)}>
                    <span className="text-5xl drop-shadow-lg transition-transform duration-500 group-hover:scale-110">
                      {post.emoji}
                    </span>
                    <span className="absolute left-3 top-3 glass rounded-full px-2.5 py-1 text-xs font-medium text-white">
                      {post.category}
                    </span>
                  </div>
                  <div className="flex flex-1 flex-col p-5">
                    <div className="flex items-center gap-3 text-xs text-white/50">
                      <span>{formatDateUz(post.date)}</span>
                      <span className="flex items-center gap-1">
                        <Clock className="h-3.5 w-3.5" /> {post.readTime}
                      </span>
                    </div>
                    <h3 className="mt-3 text-lg font-semibold leading-snug text-white">
                      {post.title}
                    </h3>
                    <p className="mt-2 line-clamp-2 flex-1 text-sm text-white/55">{post.excerpt}</p>
                    <div className="mt-4 flex items-center justify-between border-t border-white/10 pt-4">
                      <span className="text-xs text-white/50">{post.author}</span>
                      <span className="flex items-center gap-1 text-sm text-aurora-violet transition-transform group-hover:translate-x-1">
                        O'qish <ArrowUpRight className="h-4 w-4" />
                      </span>
                    </div>
                  </div>
                </GlassCard>
              </TiltCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Container>
    </>
  );
}
