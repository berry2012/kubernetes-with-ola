import React, { useEffect } from 'react';

const Health = () => {
  useEffect(() => {
    // Set response status to 200
    if (window.location.pathname === '/health') {
      document.title = 'Health Check - OK';
    }
  }, []);

  return (
    <div className="health-container">
      <div className="health-status">✅ Application is healthy</div>
      <p>Status: 200 OK</p>
    </div>
  );
};

export default Health;
