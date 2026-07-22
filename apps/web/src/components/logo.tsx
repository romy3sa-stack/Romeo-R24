import Link from 'next/link';

type LogoVariant = 'full' | 'compact' | 'icon';

type LogoProps = {
  variant?: LogoVariant;
  href?: string;
  className?: string;
  /** Light logos for dark backgrounds; dark logos for light backgrounds. */
  theme?: 'light' | 'dark';
};

const sizeClasses: Record<LogoVariant, string> = {
  full: 'h-[70px] w-auto max-w-[260px]',
  compact: 'h-10 w-auto max-w-[180px]',
  icon: 'h-10 w-10',
};

export function Logo({
  variant = 'compact',
  href = '/',
  className = '',
  theme = 'dark',
}: LogoProps) {
  const src =
    variant === 'icon'
      ? '/logo-icon.svg'
      : theme === 'light'
        ? '/logo-light.svg'
        : '/logo.svg';

  const image = (
    // eslint-disable-next-line @next/next/no-img-element -- SVG brand assets; next/image blocks SVG by default
    <img
      src={src}
      alt="Receipt24 — Tax refund made simple"
      width={variant === 'icon' ? 40 : variant === 'full' ? 260 : 180}
      height={variant === 'icon' ? 40 : variant === 'full' ? 70 : 48}
      className={`${sizeClasses[variant]} ${className}`}
    />
  );

  if (!href) {
    return image;
  }

  return (
    <Link href={href} className="inline-flex shrink-0 items-center">
      {image}
    </Link>
  );
}
