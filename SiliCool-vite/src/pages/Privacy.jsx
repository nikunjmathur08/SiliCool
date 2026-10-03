import React from 'react';
import { Link } from 'react-router-dom';

export default function Privacy() {
  return (
    <div className="mx-auto max-w-4xl px-6 py-24 min-h-[70vh]">
      <h1 className="text-4xl font-bold mb-4 text-black">Privacy Policy</h1>
      <p className="text-muted mb-8">Last updated: October 2026</p>
      
      <div className="space-y-6 text-[#353535] leading-relaxed">
        <p>
          SiliCool is an open-source application designed to provide fan control for Apple Silicon Macs. We believe in your right to privacy.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">Data Collection</h2>
        <p>
          SiliCool does not collect, store, or transmit any personally identifiable information or usage data. All sensor data and fan control instructions are processed locally on your device.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">Third-Party Services</h2>
        <p>
          We do not use any third-party analytics or tracking services within the application.
        </p>
        
        <h2 className="text-2xl font-semibold text-black mt-8">Changes to This Policy</h2>
        <p>
          We may update this Privacy Policy from time to time. Any changes will be reflected on this page.
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
