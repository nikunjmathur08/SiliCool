import React from 'react';
import { Link } from 'react-router-dom';

export default function Terms() {
  return (
    <div className="mx-auto max-w-4xl px-6 py-24 min-h-[70vh]">
      <h1 className="text-4xl font-bold mb-4 text-black">Terms of Service</h1>
      <p className="text-muted mb-8">Last updated: October 2026</p>
      
      <div className="space-y-6 text-[#353535] leading-relaxed">
        <h2 className="text-2xl font-semibold text-black mt-8">1. Acceptance of Terms</h2>
        <p>
          By downloading or using SiliCool, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">2. License</h2>
        <p>
          SiliCool is open-source software licensed under the MIT License. You are free to use, modify, and distribute it in accordance with the terms of the license.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">3. Disclaimer of Warranty</h2>
        <p>
          SiliCool interacts directly with your Mac's hardware. While we strive for safety, the software is provided "as is", without warranty of any kind. You use this application at your own risk. The developers are not liable for any damage to your hardware.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">4. Limitation of Liability</h2>
        <p>
          In no event shall the authors or copyright holders be liable for any claim, damages, or other liability arising from, out of, or in connection with the software.
        </p>
        
        <div className="mt-12">
          <Link to="/" className="text-accent hover:underline font-medium">
            ← Back to Home
          </Link>
        </div>
      </div>
    </div>
  );
}
