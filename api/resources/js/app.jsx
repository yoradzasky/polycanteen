import './bootstrap';
import '../css/app.css';


import { createRoot } from 'react-dom/client';
import { createInertiaApp } from '@inertiajs/react';
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers';
import 'leaflet/dist/leaflet.css';
import dayjs from 'dayjs';
import 'dayjs/locale/id'; 
import relativeTime from 'dayjs/plugin/relativeTime';

const appName = import.meta.env.VITE_APP_NAME || 'Laravel';

dayjs.extend(relativeTime);
dayjs.locale('id');
window.dayjs = dayjs;

createInertiaApp({
    title: (title) => `${title} - ${appName}`,
    resolve: (name) => resolvePageComponent(`./Pages/${name}.jsx`, import.meta.glob('./Pages/**/*.jsx')),
    setup({ el, App, props }) {
        const root = createRoot(el);

        root.render(<App {...props} />);
    },
    progress: {
        color: '#4B5563',
    },
});
