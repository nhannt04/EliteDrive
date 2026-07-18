import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../fleet/providers/fleet_provider.dart';
import '../../fleet/models/car.dart';

class AdminCarListScreen extends StatefulWidget {
  const AdminCarListScreen({super.key});

  @override
  State<AdminCarListScreen> createState() => _AdminCarListScreenState();
}

class _AdminCarListScreenState extends State<AdminCarListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCars();
    });
  }

  void _loadCars({String keyword = ''}) {
    context.read<FleetProvider>().fetchCars(keyword: keyword, sort: 'carId,desc');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmDialog(Car car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa xe', style: TextStyle(color: Colors.red)),
        content: Text('Bạn có chắc chắn muốn xóa xe ${car.carName} (Biển số: ${car.licensePlate}) không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final errorMessage = await context.read<FleetProvider>().deleteCar(car.carId);
              if (mounted) {
                if (errorMessage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa xe thành công'), backgroundColor: Colors.green),
                  );
                  _loadCars();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(88, 40)),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleCarStatus(Car car) async {
    final newStatus = car.carStatus == 'AVAILABLE' ? 'MAINTENANCE' : 'AVAILABLE';
    final errorMessage = await context.read<FleetProvider>().updateCarStatus(car.carId, newStatus);
    if (mounted) {
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: Colors.green),
        );
        _loadCars();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý Đội xe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCars(keyword: _searchController.text),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý Đội xe (Fleet)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm mới, cập nhật và quản lý trạng thái các xe trong hệ thống.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Tìm theo tên, hãng hoặc biển số...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            icon: Icon(Icons.search, color: Colors.white54),
                          ),
                          onSubmitted: (val) => _loadCars(keyword: val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const _AddOrEditCarDialog(),
                        ).then((_) => _loadCars());
                      },
                      icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                      label: const Text('Thêm Xe Mới', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(88, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // List Body
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : provider.errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(provider.errorMessage, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadCars(),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(88, 40)),
                              child: const Text('Thử lại'),
                            )
                          ],
                        ),
                      )
                    : provider.cars.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy xe nào trong hệ thống.', style: TextStyle(color: AppTheme.subTextColor)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: provider.cars.length,
                            itemBuilder: (context, index) {
                              final car = provider.cars[index];
                              return _buildCarCard(car);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    final isAvailable = car.carStatus == 'AVAILABLE';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: car.thumbnailUrl != null && car.thumbnailUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(ApiClient.resolveImageUrl(car.thumbnailUrl)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: car.thumbnailUrl == null || car.thumbnailUrl!.isEmpty
                  ? const Icon(Icons.directions_car, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          car.carName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isAvailable ? Colors.green : Colors.orange),
                        ),
                        child: Text(
                          isAvailable ? 'Sẵn sàng' : (car.carStatus == 'MAINTENANCE' ? 'Bảo trì' : 'Đang thuê'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Biển số: ${car.licensePlate} • ${car.brand} ${car.model}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.subTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${car.pricePerDay.toStringAsFixed(0)} / ngày',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                  ),
                  const SizedBox(height: 12),
                  // Actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => _AddOrEditCarDialog(car: car),
                          ).then((_) => _loadCars());
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Sửa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _toggleCarStatus(car),
                        icon: Icon(isAvailable ? Icons.build : Icons.check_circle, size: 16),
                        label: Text(isAvailable ? 'Bảo trì' : 'Sẵn sàng'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isAvailable ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmDialog(car),
                        tooltip: 'Xóa xe',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOrEditCarDialog extends StatefulWidget {
  final Car? car;
  
  const _AddOrEditCarDialog({this.car});

  @override
  State<_AddOrEditCarDialog> createState() => _AddOrEditCarDialogState();
}

class _AddOrEditCarDialogState extends State<_AddOrEditCarDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _colorController;
  late TextEditingController _seatsController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _thumbnailController;
  
  String _fuelType = 'GASOLINE';
  String _transmission = 'AUTOMATIC';
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.car?.carName ?? '');
    _brandController = TextEditingController(text: widget.car?.brand ?? '');
    _modelController = TextEditingController(text: widget.car?.model ?? '');
    _yearController = TextEditingController(text: widget.car != null ? widget.car!.year.toString() : '2023');
    _licensePlateController = TextEditingController(text: widget.car?.licensePlate ?? '');
    _colorController = TextEditingController(text: widget.car?.color ?? '');
    _seatsController = TextEditingController(text: widget.car != null ? widget.car!.seats.toString() : '4');
    _priceController = TextEditingController(text: widget.car != null ? widget.car!.pricePerDay.toString() : '');
    _descriptionController = TextEditingController(text: widget.car?.description ?? '');
    _thumbnailController = TextEditingController(text: widget.car?.thumbnailUrl ?? '');
    
    if (widget.car != null) {
      _fuelType = widget.car!.fuelType;
      _transmission = widget.car!.transmission;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final data = {
      "carName": _nameController.text.trim(),
      "brand": _brandController.text.trim(),
      "model": _modelController.text.trim(),
      "year": int.tryParse(_yearController.text.trim()) ?? 2023,
      "licensePlate": _licensePlateController.text.trim(),
      "color": _colorController.text.trim(),
      "seats": int.tryParse(_seatsController.text.trim()) ?? 4,
      "fuelType": _fuelType,
      "transmission": _transmission,
      "pricePerDay": double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0.0,
      "description": _descriptionController.text.trim(),
      "thumbnailUrl": _thumbnailController.text.trim(),
    };
    
    String? errorMessage;
    if (widget.car == null) {
      errorMessage = await context.read<FleetProvider>().createCar(data);
    } else {
      errorMessage = await context.read<FleetProvider>().updateCar(widget.car!.carId, data);
    }
    
    if (mounted) {
      if (errorMessage == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.car == null ? 'Thêm xe thành công!' : 'Cập nhật xe thành công!'),
            backgroundColor: Colors.green
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.car != null;
    return AlertDialog(
      title: Text(isEdit ? 'Cập nhật Xe' : 'Thêm Xe Mới', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.only(top: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildField('Tên xe', _nameController, Icons.directions_car)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Biển số', _licensePlateController, Icons.pin)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Hãng (Brand)', _brandController, Icons.branding_watermark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Mẫu (Model)', _modelController, Icons.model_training)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Năm SX', _yearController, Icons.calendar_today, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Màu sắc', _colorController, Icons.color_lens)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Số ghế', _seatsController, Icons.airline_seat_recline_normal, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Giá/ngày (\$)', _priceController, Icons.attach_money, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _fuelType,
                        decoration: const InputDecoration(labelText: 'Nhiên liệu', prefixIcon: Icon(Icons.local_gas_station)),
                        items: const [
                          DropdownMenuItem(value: 'GASOLINE', child: Text('Xăng (Gasoline)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'DIESEL', child: Text('Dầu (Diesel)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'ELECTRIC', child: Text('Điện (Electric)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) { if (val != null) setState(() => _fuelType = val); },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _transmission,
                        decoration: const InputDecoration(labelText: 'Hộp số', prefixIcon: Icon(Icons.settings)),
                        items: const [
                          DropdownMenuItem(value: 'AUTOMATIC', child: Text('Tự động (Automatic)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'MANUAL', child: Text('Số sàn (Manual)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) { if (val != null) setState(() => _transmission = val); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField('Đường dẫn ảnh (URL)', _thumbnailController, Icons.image, isRequired: false),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, minimumSize: const Size(88, 40)),
          child: Text(isEdit ? 'CẬP NHẬT' : 'THÊM MỚI'),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Bắt buộc' : null : null,
    );
  }
}
