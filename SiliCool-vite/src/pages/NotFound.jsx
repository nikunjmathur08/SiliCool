import React from 'react';
import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[70vh] px-6 py-24 text-center">
      <h1 className="text-[clamp(60px,8vw,120px)] font-bold leading-none tracking-tighter text-black">
        404
      </h1>
      <p className="mt-6 mb-8 text-[clamp(18px,2vw,24px)] text-muted max-w-md mx-auto">
        Oops! The page you're looking for doesn't exist or has been moved.
      </p>
      
      <Link 
        to="/" 
        className="inline-flex h-[47px] cursor-pointer items-center justify-center rounded-[35px] border border-[#414141e6] bg-[#000000e6] px-6 text-[16px] font-medium leading-[1.025] tracking-[-0.02em] whitespace-nowrap no-underline text-[#ffffffe6] transition-colors hover:border-accent hover:bg-accent hover:text-white"
      >
        Go back home
      </Link>
    </div>
  );
}
