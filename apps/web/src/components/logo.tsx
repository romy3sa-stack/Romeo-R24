import Image from 'next/image';
import Link from 'next/link';

type LogoVariant = 'full' | 'compact' | 'icon';

type LogoProps = {
  variant?: LogoVariant;
  href?: string;
  className?: string;
  /** Light logos for dark backgrounds; dark logos for light backgrounds. */
  theme?: 'light' | 'dark';
};

const sizes: Record<LogoVariant, { width: number; height: number }> = {
  full: { width: 260, height: 70 },
  compact: { width: 180, height: 48 },
  icon: { width: 40, height: 40 },
};

export function Logo({
  variant = 'compact',
  href = '/',
  className = '',
  theme = 'dark',
}: LogoProps) {
  const { width, height } = sizes[variant];
  const src =
    variant === 'icon'
      ? '/logo-icon.svg'
      : theme === 'light'
        ? '/logo-light.svg'
        : '/logo.svg';

  const image = (
    <Image
      src={src}
      alt="Receipt24 — Tax refund made simple"
      width={width}
      height={height}
      priority={variant === 'full'}
      className={`h-auto w-auto ${className}`}
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
