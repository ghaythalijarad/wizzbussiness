import axios from 'axios';
import { Order } from '../types';

const API_URL = 'https://api.example.com/orders'; // Replace with your actual API endpoint

export const fetchOrders = async (): Promise<Order[]> => {
    try {
        const response = await axios.get<Order[]>(API_URL);
        return response.data;
    } catch (error) {
        console.error('Error fetching orders:', error);
        throw error;
    }
};

// Additional order management functions can be added here, such as createOrder, updateOrder, deleteOrder, etc.