import React from 'react';
import OrderList from '../components/OrderList';

const Dashboard: React.FC = () => {
    return (
        <div>
            <h1>Order Dashboard</h1>
            <OrderList />
            {/* Additional UI elements for managing orders can be added here */}
        </div>
    );
};

export default Dashboard;