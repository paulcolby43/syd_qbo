class BillsController < ApplicationController
  before_filter :authenticate_user!
#  load_and_authorize_resource

  before_action :set_bill_service, only: [:index, :show, :create, :edit, :update, :update_qb, :destroy]
  before_action :set_vendor_service, only: [:index, :show, :new, :create, :edit, :update]
  before_action :set_item_service, only: [:show, :new, :create, :edit, :line_item_fields]
  before_action :set_purchase_order_service, only: [:new, :create, :edit, :update, :update_qb, :destroy]
  before_action :set_bill_payment_service, only: [:show]
  
  before_action :set_bill, only: [:show, :edit, :update, :update_qb, :destroy]

  # GET /bills
  # GET /bills.json
  def index
#    query = "Select * From Bill Where TxnDate>'#{1.month.ago.strftime("%Y-%m-%d")}'"
    @open_bills = @bill_service.query(nil, :per_page => 100).entries.find_all{ |e| e.balance > 0 }
    @open_bills = Kaminari.paginate_array(@open_bills).page(params[:page]).per(3)
#    @paid_bills = @bill_service.query(nil, :per_page => 20).entries.find_all{ |e| e.balance == 0 }
  end

  # GET /bills/1
  # GET /bills/1.json
  def show
    @vendor = @vendor_service.fetch_by_id(@bill.vendor_ref)
    @doc_number = @bill.doc_number
#    @purchase_order = @purchase_order_service.query.entries.find{ |p| p.doc_number == @doc_number }
    @bill_payment = @bill_payment_service.query.entries.find{ |b| b.doc_number == @doc_number } if @bill.balance == 0
    
    @images = Image.where(ticket_nbr: @doc_number)
  end

  # GET /bills/new
  def new
    @vendors = @vendor_service.query(nil, :per_page => 1000)
#    query = "Select * From Item Where Type = 'Inventory'"
#    @items = @item_service.query(query, :per_page => 1000)
    @items = @item_service.query(nil, :per_page => 1000)
    @purchase_order = @purchase_order_service.fetch_by_id(params[:purchase_order_id])
  end

  # GET /bills/1/edit
  def edit
    @vendors = @vendor_service.query(nil, :per_page => 1000)
    @vendor = @vendor_service.fetch_by_id(@bill.vendor_ref)
    
#    query = "Select * From Item Where Type = 'Inventory'"
#    @items = @item_service.query(query, :per_page => 1000)
    
    @items = @item_service.query(nil, :per_page => 1000)
  end
  
  # POST /bills
  # POST /bills.json
  def create
    @purchase_order = @purchase_order_service.fetch_by_id(params[:purchase_order_id])
    @bill = Quickbooks::Model::Bill.new
    @bill.vendor_id = @purchase_order.vendor_ref
    @bill.doc_number = bill_params[:doc_number]
    
    bill_params[:line_items].each do |line_item|
      item_based_expense_line_detail = Quickbooks::Model::ItemBasedExpenseLineDetail.new
      item_based_expense_line_detail.unit_price = line_item[:rate]
      item_based_expense_line_detail.quantity = line_item[:quantity]
      item_based_expense_line_detail.item_id= line_item[:item]

      bill_line_item = Quickbooks::Model::BillLineItem.new
      bill_line_item.detail_type = "ItemBasedExpenseLineDetail"
      bill_line_item.item_based_expense_line_detail = item_based_expense_line_detail
      bill_line_item.amount = line_item[:amount]
      bill_line_item.description = "Gross: #{line_item[:gross]}, Tare: #{line_item[:tare]}" unless (line_item[:gross].blank? or line_item[:tare].blank?)
      @bill.line_items.push(bill_line_item)
    end
    
    @bill = @bill_service.create(@bill)

    respond_to do |format|
      if @bill.present?
        @purchase_order.po_status = "Closed"
        @purchase_order_service.update(@purchase_order)
#        format.html { redirect_to bill_path(@bill.id), notice: 'Bill was successfully created.' }
        format.html { redirect_to bills_path, notice: 'Bill was successfully created.' }
        format.json { render :show, status: :created, location: bill_path(@bill.id) }
      else
        format.html { render :new }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_qb
    @bill.vendor_id = bill_params[:vendor]
    @bill.doc_number = bill_params[:doc_number]
    @bill.line_items.clear
    
    bill_params[:line_items].each do |line_item|
      item_based_expense_line_detail = Quickbooks::Model::ItemBasedExpenseLineDetail.new
      item_based_expense_line_detail.unit_price = line_item[:rate]
      item_based_expense_line_detail.quantity = line_item[:quantity]
      item_based_expense_line_detail.item_id= line_item[:item]

      bill_line_item = Quickbooks::Model::BillLineItem.new
      bill_line_item.detail_type = "ItemBasedExpenseLineDetail"
      bill_line_item.item_based_expense_line_detail = item_based_expense_line_detail
      bill_line_item.amount = line_item[:amount]
      bill_line_item.description = "Gross: #{line_item[:gross]}, Tare: #{line_item[:tare]}" unless (line_item[:gross].blank? or line_item[:tare].blank?)
      @bill.line_items.push(bill_line_item)
    end
    
    @bill = @bill_service.update(@bill)
    
    respond_to do |format|
      if @bill.present?
        format.html { 
          if params[:pay_ticket]
            redirect_to new_bill_payment_path(bill_id: @bill.id), notice: 'Bill was successfully updated.'
          else
            redirect_to bill_path(@bill.id), notice: 'Bill was successfully updated.' 
          end
          }
        format.json { render :show, status: :ok, location: bill_path(@bill.id) }
      else
        format.html { render :edit }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /bills/1
  # PATCH/PUT /bills/1.json
  def update
    respond_to do |format|
      if @bill.update(bill_params)
        format.html { redirect_to @bill, notice: 'Bill was successfully updated.' }
        format.json { render :show, status: :ok, location: @bill }
      else
        format.html { render :edit }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def line_item_fields
    @items = @item_service.query(nil, :per_page => 1000)
    respond_to do |format|
      format.js
    end
  end

  # DELETE /bills/1
  # DELETE /bills/1.json
  def destroy
    @bill.destroy
    respond_to do |format|
      format.html { redirect_to bills_url, notice: 'Bill was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private
    def set_bill_service
      oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, session[:token], session[:secret])
      @bill_service = Quickbooks::Service::Bill.new
      @bill_service.access_token = oauth_client
      @bill_service.company_id = session[:realm_id]
    end
    
    def set_vendor_service
      oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, session[:token], session[:secret])
      @vendor_service = Quickbooks::Service::Vendor.new
      @vendor_service.access_token = oauth_client
      @vendor_service.company_id = session[:realm_id]
    end
    
    def set_item_service
      oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, session[:token], session[:secret])
      @item_service = Quickbooks::Service::Item.new
      @item_service.access_token = oauth_client
      @item_service.company_id = session[:realm_id]
    end
    
    def set_purchase_order_service
      oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, session[:token], session[:secret])
      @purchase_order_service = Quickbooks::Service::PurchaseOrder.new
      @purchase_order_service.access_token = oauth_client
      @purchase_order_service.company_id = session[:realm_id]
    end
    
    def set_bill_payment_service
      oauth_client = OAuth::AccessToken.new($qb_oauth_consumer, session[:token], session[:secret])
      @bill_payment_service = Quickbooks::Service::Bill.new
      @bill_payment_service.access_token = oauth_client
      @bill_payment_service.company_id = session[:realm_id]
    end
    
    # Use callbacks to share common setup or constraints between actions.
    def set_bill
      #@bill = Bill.find(params[:id])
      @bill = @bill_service.fetch_by_id(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bill_params
      # order matters here in that to have access to model attributes in uploader methods, they need to show up before the file param in this permitted_params list 
      params.require(:bill).permit(:vendor, :doc_number, line_items: [:item, :description, :gross, :tare, :quantity, :rate, :amount])
    end
    
#    def line_params
#      # order matters here in that to have access to model attributes in uploader methods, they need to show up before the file param in this permitted_params list 
##      params.require(:line).permit("item")
#      params.permit("item")
#    end
end