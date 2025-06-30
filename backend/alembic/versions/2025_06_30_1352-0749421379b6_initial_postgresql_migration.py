"""Initial PostgreSQL migration

Revision ID: 0749421379b6
Revises: 
Create Date: 2025-06-30 13:52:19.167859+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0749421379b6'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('email', sa.String(length=320), nullable=False),
        sa.Column('hashed_password', sa.String(length=1024), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('is_superuser', sa.Boolean(), nullable=False),
        sa.Column('is_verified', sa.Boolean(), nullable=False),
        sa.Column('full_name', sa.String(length=100), nullable=True),
        sa.Column('phone_number', sa.String(length=20), nullable=True),
        sa.Column('profile_image_url', sa.Text(), nullable=True),
        sa.Column('business_type', sa.String(length=50), nullable=True),
        sa.Column('business_name', sa.String(length=200), nullable=True),
        sa.Column('language_preference', sa.String(length=10), nullable=False, default='en'),
        sa.Column('timezone', sa.String(length=50), nullable=False, default='UTC'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('owner_name', sa.String(length=100), nullable=True),
        sa.Column('owner_national_id', sa.String(length=50), nullable=True),
        sa.Column('owner_date_of_birth', sa.DateTime(), nullable=True),
        sa.Column('license_document', sa.Text(), nullable=True),
        sa.Column('identity_document', sa.Text(), nullable=True),
        sa.Column('health_certificate', sa.Text(), nullable=True),
        sa.Column('owner_photo', sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=False)

    # Create businesses table
    op.create_table(
        'businesses',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('business_type', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('phone', sa.String(length=20), nullable=True),
        sa.Column('email', sa.String(length=100), nullable=True),
        sa.Column('website', sa.String(length=200), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('is_online', sa.Boolean(), nullable=False, default=False),
        sa.Column('is_verified', sa.Boolean(), nullable=False, default=False),
        sa.Column('operating_hours', sa.Text(), nullable=True),
        sa.Column('street_address', sa.String(length=200), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('district', sa.String(length=100), nullable=True),
        sa.Column('country', sa.String(length=100), nullable=True),
        sa.Column('postal_code', sa.String(length=20), nullable=True),
        sa.Column('neighborhood', sa.String(length=100), nullable=True),
        sa.Column('building_number', sa.String(length=20), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column('logo_url', sa.Text(), nullable=True),
        sa.Column('cover_image_url', sa.Text(), nullable=True),
        sa.Column('gallery_images', sa.Text(), nullable=True),
        sa.Column('average_rating', sa.Float(), nullable=False, default=0.0),
        sa.Column('total_reviews', sa.Integer(), nullable=False, default=0),
        sa.Column('total_orders', sa.Integer(), nullable=False, default=0),
        sa.Column('delivery_fee', sa.Float(), nullable=False, default=0.0),
        sa.Column('minimum_order', sa.Float(), nullable=False, default=0.0),
        sa.Column('tax_rate', sa.Float(), nullable=False, default=0.0),
        sa.Column('owner_id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('platform_business_id', sa.String(length=100), nullable=True),
        sa.Column('sync_status', sa.String(length=20), nullable=False, default='pending'),
        sa.Column('last_sync_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_businesses_name'), 'businesses', ['name'], unique=False)
    op.create_index(op.f('ix_businesses_platform_business_id'), 'businesses', ['platform_business_id'], unique=False)

    # Create addresses table
    op.create_table(
        'addresses',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('country', sa.String(length=100), nullable=False),
        sa.Column('city', sa.String(length=100), nullable=False),
        sa.Column('district', sa.String(length=100), nullable=False),
        sa.Column('neighbourhood', sa.String(length=100), nullable=False),
        sa.Column('street', sa.String(length=200), nullable=False),
        sa.Column('building_number', sa.String(length=20), nullable=True),
        sa.Column('zip_code', sa.String(length=20), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('business_id', sa.UUID(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create item_categories table
    op.create_table(
        'item_categories',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('business_id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.String(length=500), nullable=True),
        sa.Column('display_order', sa.Integer(), nullable=False, default=0),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('color', sa.String(length=7), nullable=True),
        sa.Column('icon', sa.String(length=200), nullable=True),
        sa.Column('items_count', sa.Integer(), nullable=False, default=0),
        sa.Column('active_items_count', sa.Integer(), nullable=False, default=0),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create items table
    op.create_table(
        'items',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('business_id', sa.UUID(), nullable=False),
        sa.Column('category_id', sa.UUID(), nullable=True),
        sa.Column('created_by', sa.UUID(), nullable=True),
        sa.Column('updated_by', sa.UUID(), nullable=True),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('price', sa.Float(), nullable=False),
        sa.Column('cost', sa.Float(), nullable=True),
        sa.Column('category_name', sa.String(length=100), nullable=True),
        sa.Column('item_type', sa.String(length=20), nullable=False, default='product'),
        sa.Column('status', sa.String(length=20), nullable=False, default='active'),
        sa.Column('is_available', sa.Boolean(), nullable=False, default=True),
        sa.Column('stock_quantity', sa.Integer(), nullable=True),
        sa.Column('low_stock_threshold', sa.Integer(), nullable=True),
        sa.Column('track_inventory', sa.Boolean(), nullable=False, default=False),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('images', sa.JSON(), nullable=True),
        sa.Column('thumbnail', sa.String(length=500), nullable=True),
        sa.Column('variants', sa.JSON(), nullable=True),
        sa.Column('customizable', sa.Boolean(), nullable=False, default=False),
        sa.Column('preparation_time', sa.Integer(), nullable=True),
        sa.Column('nutritional_info', sa.JSON(), nullable=True),
        sa.Column('allergens', sa.JSON(), nullable=True),
        sa.Column('ingredients', sa.JSON(), nullable=True),
        sa.Column('prescription_required', sa.Boolean(), nullable=True),
        sa.Column('medicine_type', sa.String(length=50), nullable=True),
        sa.Column('dosage', sa.String(length=100), nullable=True),
        sa.Column('manufacturer', sa.String(length=200), nullable=True),
        sa.Column('expiry_date', sa.DateTime(), nullable=True),
        sa.Column('brand', sa.String(length=100), nullable=True),
        sa.Column('model', sa.String(length=100), nullable=True),
        sa.Column('sku', sa.String(length=100), nullable=True),
        sa.Column('barcode', sa.String(length=100), nullable=True),
        sa.Column('views_count', sa.Integer(), nullable=False, default=0),
        sa.Column('orders_count', sa.Integer(), nullable=False, default=0),
        sa.Column('rating', sa.Float(), nullable=False, default=0.0),
        sa.Column('reviews_count', sa.Integer(), nullable=False, default=0),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('search_keywords', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.ForeignKeyConstraint(['category_id'], ['item_categories.id'], ),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ),
        sa.ForeignKeyConstraint(['updated_by'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create orders table
    op.create_table(
        'orders',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('order_number', sa.String(length=50), nullable=False),
        sa.Column('business_id', sa.UUID(), nullable=False),
        sa.Column('customer_id', sa.String(length=100), nullable=True),
        sa.Column('customer_name', sa.String(length=200), nullable=False),
        sa.Column('customer_phone', sa.String(length=20), nullable=False),
        sa.Column('customer_email', sa.String(length=254), nullable=True),
        sa.Column('items', sa.JSON(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, default='pending'),
        sa.Column('delivery_type', sa.String(length=20), nullable=False, default='delivery'),
        sa.Column('delivery_address', sa.JSON(), nullable=True),
        sa.Column('delivery_notes', sa.Text(), nullable=True),
        sa.Column('order_date', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('requested_delivery_time', sa.DateTime(), nullable=True),
        sa.Column('estimated_delivery_time', sa.DateTime(), nullable=True),
        sa.Column('confirmed_at', sa.DateTime(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('payment_info', sa.JSON(), nullable=False),
        sa.Column('preparation_time_minutes', sa.Integer(), nullable=True),
        sa.Column('special_instructions', sa.Text(), nullable=True),
        sa.Column('source', sa.String(length=50), nullable=False, default='wizz_app'),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('business_notes', sa.Text(), nullable=True),
        sa.Column('estimated_ready_time', sa.DateTime(), nullable=True),
        sa.Column('assigned_driver_info', sa.JSON(), nullable=True),
        sa.Column('driver_assigned_at', sa.DateTime(), nullable=True),
        sa.Column('picked_up_at', sa.DateTime(), nullable=True),
        sa.Column('delivered_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('order_number')
    )

    # Create business_pos_settings table
    op.create_table(
        'business_pos_settings',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('business_id', sa.UUID(), nullable=False),
        sa.Column('enabled', sa.Boolean(), nullable=False, default=False),
        sa.Column('auto_send_orders', sa.Boolean(), nullable=False, default=False),
        sa.Column('system_type', sa.String(length=50), nullable=False, default='genericApi'),
        sa.Column('api_endpoint', sa.String(length=500), nullable=True),
        sa.Column('api_key', sa.String(length=500), nullable=True),
        sa.Column('access_token', sa.String(length=1000), nullable=True),
        sa.Column('location_id', sa.String(length=100), nullable=True),
        sa.Column('timeout_seconds', sa.Integer(), nullable=False, default=30),
        sa.Column('retry_attempts', sa.Integer(), nullable=False, default=3),
        sa.Column('test_mode', sa.Boolean(), nullable=False, default=False),
        sa.Column('last_connection_test', sa.DateTime(), nullable=True),
        sa.Column('last_connection_status', sa.Boolean(), nullable=False, default=False),
        sa.Column('last_error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('business_id')
    )

    # Create pos_order_sync_logs table
    op.create_table(
        'pos_order_sync_logs',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('business_id', sa.UUID(), nullable=False),
        sa.Column('order_id', sa.UUID(), nullable=False),
        sa.Column('pos_system_type', sa.String(length=50), nullable=False),
        sa.Column('sync_status', sa.String(length=20), nullable=False),
        sa.Column('sync_timestamp', sa.DateTime(), nullable=False, default=sa.text('now()')),
        sa.Column('pos_order_id', sa.String(length=100), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('retry_count', sa.Integer(), nullable=False, default=0),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
        sa.PrimaryKeyConstraint('id')
    )


def downgrade() -> None:
    """Downgrade schema."""
    # Drop tables in reverse order to handle foreign key constraints
    op.drop_table('pos_order_sync_logs')
    op.drop_table('business_pos_settings')
    op.drop_table('orders')
    op.drop_table('items')
    op.drop_table('item_categories')
    op.drop_table('addresses')
    op.drop_index(op.f('ix_businesses_platform_business_id'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_name'), table_name='businesses')
    op.drop_table('businesses')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
