export interface Order {
    id: string;
    customerId: string;
    items: OrderItem[];
    totalAmount: number;
    status: 'pending' | 'completed' | 'canceled';
    createdAt: Date;
}

export interface OrderItem {
    productId: string;
    quantity: number;
    price: number;
}

export interface Customer {
    id: string;
    name: string;
    email: string;
    phone: string;
}