import React from 'react';
import { createRoot } from 'react-dom/client';

function App(){
  return <h1>StartTech Frontend</h1>
}

const root = createRoot(document.getElementById('root'));
root.render(<App/>);
